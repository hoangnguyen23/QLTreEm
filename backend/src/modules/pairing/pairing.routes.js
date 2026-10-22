const express = require("express")
const router = express.Router()
const asyncHandler = require("../../utils/asyncHandler")
const authenticate = require("../../middlewares/auth.middleware")
const authorize = require("../../middlewares/permission.middleware")
const validate = require("../../middlewares/validation.middleware")
const {
  generatePairing,
  getPairingStatus,
  confirmPairing,
} = require("./pairing.controller")
const {
  generatePairingSchema,
  confirmPairingSchema,
  idSchema,
} = require("./pairing.validate")

// PARENT creates QR pairing session
router.post("/generate", authenticate, authorize("PARENT"), validate(generatePairingSchema), asyncHandler(generatePairing))

// PARENT checks pairing status
router.get("/:id/status", authenticate, authorize("PARENT", "ADMIN"), validate(idSchema), asyncHandler(getPairingStatus))

// CHILD/device confirms pairing by scanning QR and sending pairing token
router.post("/confirm", validate(confirmPairingSchema), asyncHandler(confirmPairing))

module.exports = router
