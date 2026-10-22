const z = require("zod")

const biometricLoginBodySchema = z.object({
  biometricToken: z.string().min(1, "biometricToken không được để trống"),
})

const biometricLoginSchema = z.object({
  body: biometricLoginBodySchema,
})

module.exports = {
  biometricLoginSchema,
}
