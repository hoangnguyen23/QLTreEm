const z = require("zod")

const createChildBodySchema = z.object({
  name: z.string().trim().min(1, "Tên trẻ không được để trống").max(100),
  dateOfBirth: z.string().datetime().optional().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional()),
  avatarUrl: z.string().url().optional().or(z.literal("")),
  notes: z.string().max(500).optional(),
  childEmail: z.string().email("Email không hợp lệ").optional().or(z.literal("")).nullable(),
})

const updateChildBodySchema = z.object({
  name: z.string().trim().min(1).max(100).optional(),
  dateOfBirth: z.string().datetime().optional().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional()),
  avatarUrl: z.string().url().optional().or(z.literal("")),
  notes: z.string().max(500).optional(),
  isActive: z.boolean().optional(),
  childEmail: z.string().email("Email không hợp lệ").optional().or(z.literal("")).nullable(),
})

const idParamsSchema = z.object({
  id: z.string(),
})

const createChildSchema = z.object({
  body: createChildBodySchema,
})

const updateChildSchema = z.object({
  params: idParamsSchema,
  body: updateChildBodySchema,
})

const idSchema = z.object({
  params: idParamsSchema,
})

module.exports = {
  createChildSchema,
  updateChildSchema,
  idSchema,
}
