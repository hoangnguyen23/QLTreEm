const express = require("express")
const router = express.Router()
const asyncHandler = require("../../utils/asyncHandler")
const authenticate = require("../../middlewares/auth.middleware")
const authorize = require("../../middlewares/permission.middleware")
const validate = require("../../middlewares/validation.middleware")
const {
  getAlerts,
  triggerSos,
  markAlertRead,
  markAlertResolved,
  deleteAlert,
} = require("./alert.controller")
const { listAlertsSchema, idSchema } = require("./alert.validate")

router.get("/", authenticate, authorize("PARENT", "ADMIN", "CHILD"), validate(listAlertsSchema), asyncHandler(getAlerts))
router.post("/sos", authenticate, authorize("CHILD", "PARENT"), asyncHandler(triggerSos))
router.patch("/:id/read", authenticate, authorize("PARENT", "ADMIN", "CHILD"), validate(idSchema), asyncHandler(markAlertRead))
router.patch("/:id/resolve", authenticate, authorize("PARENT", "ADMIN"), validate(idSchema), asyncHandler(markAlertResolved))
router.delete("/:id", authenticate, authorize("PARENT", "ADMIN"), validate(idSchema), asyncHandler(deleteAlert))

module.exports = router
