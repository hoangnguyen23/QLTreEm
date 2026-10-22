const z = require("zod")

const generatePairingBodySchema = z.object({
  childProfileId: z.string().min(1, "childProfileId không được để trống"),
})

const confirmPairingBodySchema = z.object({
  token: z.string().min(1, "Mã ghép nối không được để trống"),
  deviceIdentifier: z.string().min(1, "deviceIdentifier không được để trống"),
  name: z.string().trim().min(1, "Tên thiết bị không được để trống"),
  platform: z.enum(["ANDROID", "IOS", "OTHER"]).default("ANDROID"),
  childUserId: z.string().optional(),
})

const idParamsSchema = z.object({
  id: z.string(),
})

const generatePairingSchema = z.object({
  body: generatePairingBodySchema,
})

const confirmPairingSchema = z.object({
  body: confirmPairingBodySchema,
})

const idSchema = z.object({
  params: idParamsSchema,
})

module.exports = {
  generatePairingSchema,
  confirmPairingSchema,
  idSchema,
}
