const z = require("zod")

const reportLocationBodySchema = z.object({
  deviceId: z.string().min(1, "deviceId không được để trống"),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  accuracy: z.number().optional().nullable(),
  altitude: z.number().optional().nullable(),
  speed: z.number().optional().nullable(),
  recordedAt: z.union([z.string().datetime({ offset: true }), z.string().datetime(), z.string()]).optional(),
})

const deviceIdParamsSchema = z.object({
  deviceId: z.string().min(1),
})

const historyQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(200).default(50),
  startTime: z.string().datetime().optional(),
  endTime: z.string().datetime().optional(),
})

const reportLocationSchema = z.object({
  body: reportLocationBodySchema,
})

const getLatestLocationSchema = z.object({
  params: deviceIdParamsSchema,
})

const getLocationHistorySchema = z.object({
  params: deviceIdParamsSchema,
  query: historyQuerySchema.optional(),
})

module.exports = {
  reportLocationSchema,
  getLatestLocationSchema,
  getLocationHistorySchema,
}
