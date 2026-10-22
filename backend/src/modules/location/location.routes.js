const express = require("express")
const router = express.Router()
const asyncHandler = require("../../utils/asyncHandler")
const authenticate = require("../../middlewares/auth.middleware")
const authorize = require("../../middlewares/permission.middleware")
const validate = require("../../middlewares/validation.middleware")
const {
  reportLocation,
  getLatestLocation,
  getLocationHistory,
} = require("./location.controller")
const {
  reportLocationSchema,
  getLatestLocationSchema,
  getLocationHistorySchema,
} = require("./location.validate")

// CHILD device or PARENT/ADMIN updates GPS location
router.post("/", authenticate, authorize("CHILD", "PARENT", "ADMIN"), validate(reportLocationSchema), asyncHandler(reportLocation))

// PARENT or ADMIN views latest location of a device
router.get("/device/:deviceId/latest", authenticate, authorize("PARENT", "ADMIN"), validate(getLatestLocationSchema), asyncHandler(getLatestLocation))

// PARENT or ADMIN views location history of a device
router.get("/device/:deviceId/history", authenticate, authorize("PARENT", "ADMIN"), validate(getLocationHistorySchema), asyncHandler(getLocationHistory))

module.exports = router
