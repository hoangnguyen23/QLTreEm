const z = require("zod")

const updateDeviceBodySchema = z.object({
  name: z.string().trim().min(1).max(100).optional(),
  status: z.enum(["ACTIVE", "INACTIVE", "LOST", "UNPAIRED"]).optional(),
  isActive: z.boolean().optional(),
})

const idParamsSchema = z.object({
  id: z.string(),
})

const updateDeviceSchema = z.object({
  params: idParamsSchema,
  body: updateDeviceBodySchema,
})

const idSchema = z.object({
  params: idParamsSchema,
})

module.exports = {
  updateDeviceSchema,
  idSchema,
}
