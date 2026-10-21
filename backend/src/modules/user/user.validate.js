const z = require("zod")

const getUsersQuerySchema = z.object({
  role: z.enum(["ADMIN", "PARENT", "CHILD"]).optional(),
  search: z.string().trim().default(""),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(10),
  sort: z.enum(["id", "name", "email", "role"]).default("id"),
  order: z.enum(["asc", "desc"]).default("asc"),
})

const idParamsSchema = z.object({
  id: z.string(),
})

const updateProfileBodySchema = z.object({
  name: z.string().optional(),
  phone: z.string().optional(),
  address: z.string().optional(),
})

const updateUserBodySchema = z.object({
  name: z.string().optional(),
  phone: z.string().optional(),
  address: z.string().optional(),
  email: z.string().email().optional(),
})

const updateRoleBodySchema = z.object({
  role: z.enum(["ADMIN", "PARENT", "CHILD"]),
})

const getUsersSchema = z.object({
  query: getUsersQuerySchema,
})
const idSchema = z.object({
  params: idParamsSchema,
})

const updateProfileSchema = z.object({
  body: updateProfileBodySchema,
})

const updateUserSchema = z.object({
  params: idParamsSchema,
  body: updateUserBodySchema,
})

const updateRoleSchema = z.object({
  params: idParamsSchema,
  body: updateRoleBodySchema,
})

module.exports = {
  getUsersSchema,
  idSchema,
  updateProfileSchema,
  updateUserSchema,
  updateRoleSchema,
}
