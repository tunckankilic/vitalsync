/// VitalSync — Lambda Sync Handler.
///
/// REST API endpoints for VitalSync single-table DynamoDB design.
/// PK: USER#{cognitoIdentityId}, SK: {PREFIX}#{recordId}
/// Endpoints: push, pull, delete, user-data (GDPR), export (GDPR)

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const {
  BatchWriteCommand,
  DeleteCommand,
  DynamoDBDocumentClient,
  PutCommand,
  QueryCommand,
} = require('@aws-sdk/lib-dynamodb');
const awsServerlessExpressMiddleware = require('aws-serverless-express/middleware');
const bodyParser = require('body-parser');
const express = require('express');

const ddbClient = new DynamoDBClient({ region: process.env.TABLE_REGION });
const ddbDocClient = DynamoDBDocumentClient.from(ddbClient);

let tableName = 'vitalsynchDBtable';
if (process.env.ENV && process.env.ENV !== 'NONE') {
  tableName = tableName + '-' + process.env.ENV;
}

// Collection name → DynamoDB SK prefix mapping
const COLLECTION_PREFIX = {
  medications: 'MED',
  medication_logs: 'MEDLOG',
  symptoms: 'SYMPTOM',
  workout_sessions: 'WSESSION',
  workout_sets: 'WSET',
  personal_records: 'PR',
  achievements: 'ACH',
  insights: 'INSIGHT',
  // 2.0 measurement layer. health_samples is deliberately absent: activity and
  // sleep samples stay local and are re-imported from the platform health
  // store on a new device, so paying to store them here buys nothing.
  meals: 'MEAL',
  glucose_readings: 'GLUCOSE',
  calibration_metrics: 'CALMETRIC',
};

// Reverse mapping: prefix → collection name
const PREFIX_COLLECTION = Object.fromEntries(
  Object.entries(COLLECTION_PREFIX).map(([k, v]) => [v, k])
);

/// Extract Cognito Identity ID from API Gateway event.
function getUserId(req) {
  const identity = req.apiGateway?.event?.requestContext?.identity;
  return identity?.cognitoIdentityId || null;
}

/// Parse SK back to { collection, recordId }.
function parseSK(sk) {
  const hashIndex = sk.indexOf('#');
  if (hashIndex === -1) return null;
  const prefix = sk.substring(0, hashIndex);
  const recordId = sk.substring(hashIndex + 1);
  const collection = PREFIX_COLLECTION[prefix];
  if (!collection) return null;
  return { collection, recordId };
}

const app = express();
app.use(bodyParser.json());
app.use(awsServerlessExpressMiddleware.eventContext());

// CORS
app.use(function (req, res, next) {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', '*');
  next();
});

/************************************
 * POST /sync/push — Batch push records
 *
 * Body: { records: [{ collection, recordId, data, lastModifiedAt }] }
 * Uses conditional write (last-write-wins) for conflict resolution.
 ************************************/
app.post('/sync/push', async function (req, res) {
  const userId = getUserId(req);
  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const { records } = req.body;
  if (!Array.isArray(records) || records.length === 0) {
    return res.status(400).json({ error: 'records array is required' });
  }

  let successCount = 0;
  const errors = [];

  for (const record of records) {
    const { collection, recordId, data, lastModifiedAt } = record;
    const prefix = COLLECTION_PREFIX[collection];
    if (!prefix) {
      errors.push({ recordId, error: `Unknown collection: ${collection}` });
      continue;
    }

    const pk = `USER#${userId}`;
    const sk = `${prefix}#${recordId}`;
    const modifiedAt = lastModifiedAt || new Date().toISOString();

    const item = {
      PK: pk,
      SK: sk,
      data: typeof data === 'string' ? data : JSON.stringify(data),
      lastModifiedAt: modifiedAt,
    };

    try {
      // Conditional write: only overwrite if incoming lastModifiedAt is newer
      // or if item does not exist yet
      await ddbDocClient.send(
        new PutCommand({
          TableName: tableName,
          Item: item,
          ConditionExpression:
            'attribute_not_exists(PK) OR lastModifiedAt < :incoming',
          ExpressionAttributeValues: {
            ':incoming': modifiedAt,
          },
        })
      );
      successCount++;
    } catch (err) {
      if (err.name === 'ConditionalCheckFailedException') {
        // Server has newer version — skip silently (last-write-wins)
        successCount++;
      } else {
        errors.push({ recordId, error: err.message });
      }
    }
  }

  res.json({ success: true, count: successCount, errors });
});

/************************************
 * GET /sync/pull — Incremental pull
 *
 * Query params:
 *   since (optional) — ISO 8601 timestamp, only return records modified after this
 *   collection (optional) — collection name to filter by SK prefix
 ************************************/
app.get('/sync/pull', async function (req, res) {
  const userId = getUserId(req);
  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const pk = `USER#${userId}`;
  const since = req.query.since;
  const collection = req.query.collection;

  try {
    let items = [];

    if (since) {
      // Use lastModifiedAt-index GSI for incremental sync
      const queryParams = {
        TableName: tableName,
        IndexName: 'lastModifiedAt-index',
        KeyConditionExpression: 'PK = :pk AND lastModifiedAt > :since',
        ExpressionAttributeValues: {
          ':pk': pk,
          ':since': since,
        },
      };

      // If collection filter specified, add SK prefix filter
      if (collection) {
        const prefix = COLLECTION_PREFIX[collection];
        if (!prefix) {
          return res.status(400).json({ error: `Unknown collection: ${collection}` });
        }
        queryParams.FilterExpression = 'begins_with(SK, :skPrefix)';
        queryParams.ExpressionAttributeValues[':skPrefix'] = `${prefix}#`;
      }

      const data = await ddbDocClient.send(new QueryCommand(queryParams));
      items = data.Items || [];

      // Handle pagination
      let lastKey = data.LastEvaluatedKey;
      while (lastKey) {
        queryParams.ExclusiveStartKey = lastKey;
        const nextPage = await ddbDocClient.send(new QueryCommand(queryParams));
        items = items.concat(nextPage.Items || []);
        lastKey = nextPage.LastEvaluatedKey;
      }
    } else {
      // Full sync — query by PK on main table
      const queryParams = {
        TableName: tableName,
        KeyConditionExpression: 'PK = :pk',
        ExpressionAttributeValues: {
          ':pk': pk,
        },
      };

      if (collection) {
        const prefix = COLLECTION_PREFIX[collection];
        if (!prefix) {
          return res.status(400).json({ error: `Unknown collection: ${collection}` });
        }
        queryParams.KeyConditionExpression += ' AND begins_with(SK, :skPrefix)';
        queryParams.ExpressionAttributeValues[':skPrefix'] = `${prefix}#`;
      }

      const data = await ddbDocClient.send(new QueryCommand(queryParams));
      items = data.Items || [];

      let lastKey = data.LastEvaluatedKey;
      while (lastKey) {
        queryParams.ExclusiveStartKey = lastKey;
        const nextPage = await ddbDocClient.send(new QueryCommand(queryParams));
        items = items.concat(nextPage.Items || []);
        lastKey = nextPage.LastEvaluatedKey;
      }
    }

    // Convert DynamoDB items to API response format
    const records = items
      .map((item) => {
        const parsed = parseSK(item.SK);
        if (!parsed) return null;

        let recordData = item.data;
        if (typeof recordData === 'string') {
          try {
            recordData = JSON.parse(recordData);
          } catch (_) {
            // Keep as string if not valid JSON
          }
        }

        return {
          collection: parsed.collection,
          recordId: parsed.recordId,
          data: recordData,
          lastModifiedAt: item.lastModifiedAt,
        };
      })
      .filter(Boolean);

    res.json({ records });
  } catch (err) {
    res.status(500).json({ error: 'Pull failed: ' + err.message });
  }
});

/************************************
 * POST /sync/delete — Delete a single record
 *
 * Body: { collection, recordId }
 ************************************/
app.post('/sync/delete', async function (req, res) {
  const userId = getUserId(req);
  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const { collection, recordId } = req.body;
  const prefix = COLLECTION_PREFIX[collection];
  if (!prefix || !recordId) {
    return res.status(400).json({ error: 'Valid collection and recordId required' });
  }

  try {
    await ddbDocClient.send(
      new DeleteCommand({
        TableName: tableName,
        Key: {
          PK: `USER#${userId}`,
          SK: `${prefix}#${recordId}`,
        },
      })
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Delete failed: ' + err.message });
  }
});

/************************************
 * DELETE /sync/user-data — GDPR right to erasure
 *
 * Deletes ALL records for the authenticated user.
 ************************************/
app.delete('/sync/user-data', async function (req, res) {
  const userId = getUserId(req);
  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const pk = `USER#${userId}`;

  try {
    // Query all items for this user
    let items = [];
    const queryParams = {
      TableName: tableName,
      KeyConditionExpression: 'PK = :pk',
      ExpressionAttributeValues: { ':pk': pk },
      ProjectionExpression: 'PK, SK',
    };

    const data = await ddbDocClient.send(new QueryCommand(queryParams));
    items = data.Items || [];

    let lastKey = data.LastEvaluatedKey;
    while (lastKey) {
      queryParams.ExclusiveStartKey = lastKey;
      const nextPage = await ddbDocClient.send(new QueryCommand(queryParams));
      items = items.concat(nextPage.Items || []);
      lastKey = nextPage.LastEvaluatedKey;
    }

    // Batch delete in groups of 25 (DynamoDB limit)
    let deletedCount = 0;
    for (let i = 0; i < items.length; i += 25) {
      const batch = items.slice(i, i + 25);
      const deleteRequests = batch.map((item) => ({
        DeleteRequest: {
          Key: { PK: item.PK, SK: item.SK },
        },
      }));

      await ddbDocClient.send(
        new BatchWriteCommand({
          RequestItems: {
            [tableName]: deleteRequests,
          },
        })
      );
      deletedCount += batch.length;
    }

    res.json({ success: true, deletedCount });
  } catch (err) {
    res.status(500).json({ error: 'User data deletion failed: ' + err.message });
  }
});

/************************************
 * GET /sync/export — GDPR data portability
 *
 * Exports ALL user data grouped by collection.
 ************************************/
app.get('/sync/export', async function (req, res) {
  const userId = getUserId(req);
  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const pk = `USER#${userId}`;

  try {
    let items = [];
    const queryParams = {
      TableName: tableName,
      KeyConditionExpression: 'PK = :pk',
      ExpressionAttributeValues: { ':pk': pk },
    };

    const data = await ddbDocClient.send(new QueryCommand(queryParams));
    items = data.Items || [];

    let lastKey = data.LastEvaluatedKey;
    while (lastKey) {
      queryParams.ExclusiveStartKey = lastKey;
      const nextPage = await ddbDocClient.send(new QueryCommand(queryParams));
      items = items.concat(nextPage.Items || []);
      lastKey = nextPage.LastEvaluatedKey;
    }

    // Group by collection
    const grouped = {};
    for (const item of items) {
      const parsed = parseSK(item.SK);
      if (!parsed) continue;

      if (!grouped[parsed.collection]) {
        grouped[parsed.collection] = [];
      }

      let recordData = item.data;
      if (typeof recordData === 'string') {
        try {
          recordData = JSON.parse(recordData);
        } catch (_) {
          // Keep as string
        }
      }

      grouped[parsed.collection].push({
        recordId: parsed.recordId,
        data: recordData,
        lastModifiedAt: item.lastModifiedAt,
      });
    }

    res.json({
      userId,
      exportedAt: new Date().toISOString(),
      data: grouped,
    });
  } catch (err) {
    res.status(500).json({ error: 'Export failed: ' + err.message });
  }
});

app.listen(3000, function () {
  console.log('App started');
});

module.exports = app;
