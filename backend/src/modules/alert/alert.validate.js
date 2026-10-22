const z = require("zod")

const listAlertsQuerySchema = z.object({
  status: z.enum(["UNREAD", "READ", "RESOLVED"]).optional(),
  type: z.enum(["SAFE_ZONE_EXIT", "DEVICE_OFFLINE", "LOW_BATTERY", "SCREEN_TIME_LIMIT", "OTHER"]).optional(),
  childId: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(50),
  page: z.coerce.number().int().min(1).default(1),
})

const idParamsSchema = z.object({
  id: z.string(),
})

const listAlertsSchema = z.object({
  query: listAlertsQuerySchema.optional(),
})

const idSchema = z.object({
  params: idParamsSchema,
})

module.exports = {
  listAlertsSchema,
  idSchema,
}
