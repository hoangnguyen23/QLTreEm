const z = require("zod")

const createSafeZoneBodySchema = z.object({
  name: z.string().trim().min(1, "Tên vùng an toàn không được để trống").max(100),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  radius: z.number().positive("Bán kính phải lớn hơn 0"),
  childProfileId: z.string().min(1, "childProfileId không được để trống"),
})

const updateSafeZoneBodySchema = z.object({
  name: z.string().trim().min(1).max(100).optional(),
  latitude: z.number().min(-90).max(90).optional(),
  longitude: z.number().min(-180).max(180).optional(),
  radius: z.number().positive().optional(),
  isActive: z.boolean().optional(),
})

const idParamsSchema = z.object({
  id: z.string(),
})

const listSafeZonesQuerySchema = z.object({
  childProfileId: z.string().optional(),
})

const createSafeZoneSchema = z.object({
  body: createSafeZoneBodySchema,
})

const updateSafeZoneSchema = z.object({
  params: idParamsSchema,
  body: updateSafeZoneBodySchema,
})

const idSchema = z.object({
  params: idParamsSchema,
})

const listSafeZonesSchema = z.object({
  query: listSafeZonesQuerySchema.optional(),
})

module.exports = {
  createSafeZoneSchema,
  updateSafeZoneSchema,
  idSchema,
  listSafeZonesSchema,
}
