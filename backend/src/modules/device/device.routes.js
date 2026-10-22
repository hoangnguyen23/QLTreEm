const express = require("express")
const router = express.Router()
const asyncHandler = require("../../utils/asyncHandler")
const authenticate = require("../../middlewares/auth.middleware")
const authorize = require("../../middlewares/permission.middleware")
const validate = require("../../middlewares/validation.middleware")
const {
  getDevices,
  getDeviceById,
  updateDevice,
  deleteDevice,
} = require("./device.controller")
const { updateDeviceSchema, idSchema } = require("./device.validate")

router.get("/", authenticate, authorize("PARENT", "ADMIN"), asyncHandler(getDevices))
router.get("/:id", authenticate, authorize("PARENT", "ADMIN"), validate(idSchema), asyncHandler(getDeviceById))
router.patch("/:id", authenticate, authorize("PARENT", "ADMIN"), validate(updateDeviceSchema), asyncHandler(updateDevice))
router.delete("/:id", authenticate, authorize("PARENT", "ADMIN"), validate(idSchema), asyncHandler(deleteDevice))

module.exports = router
