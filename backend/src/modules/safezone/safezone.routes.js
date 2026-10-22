const express = require("express")
const router = express.Router()
const asyncHandler = require("../../utils/asyncHandler")
const authenticate = require("../../middlewares/auth.middleware")
const authorize = require("../../middlewares/permission.middleware")
const validate = require("../../middlewares/validation.middleware")
const {
  createSafeZone,
  getSafeZones,
  getSafeZoneById,
  updateSafeZone,
  deleteSafeZone,
} = require("./safezone.controller")
const {
  createSafeZoneSchema,
  updateSafeZoneSchema,
  idSchema,
  listSafeZonesSchema,
} = require("./safezone.validate")

router.post("/", authenticate, authorize("PARENT"), validate(createSafeZoneSchema), asyncHandler(createSafeZone))
router.get("/", authenticate, authorize("PARENT", "ADMIN"), validate(listSafeZonesSchema), asyncHandler(getSafeZones))
router.get("/:id", authenticate, authorize("PARENT", "ADMIN"), validate(idSchema), asyncHandler(getSafeZoneById))
router.patch("/:id", authenticate, authorize("PARENT", "ADMIN"), validate(updateSafeZoneSchema), asyncHandler(updateSafeZone))
router.delete("/:id", authenticate, authorize("PARENT", "ADMIN"), validate(idSchema), asyncHandler(deleteSafeZone))

module.exports = router
