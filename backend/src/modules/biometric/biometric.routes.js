const express = require("express")
const router = express.Router()
const asyncHandler = require("../../utils/asyncHandler")
const authenticate = require("../../middlewares/auth.middleware")
const validate = require("../../middlewares/validation.middleware")
const {
  getBiometricStatus,
  enableBiometric,
  disableBiometric,
  biometricLogin,
} = require("./biometric.controller")
const { biometricLoginSchema } = require("./biometric.validate")

// Kiểm tra trạng thái vân tay
router.get("/status", authenticate, asyncHandler(getBiometricStatus))

// Bật đăng nhập vân tay
router.post("/enable", authenticate, asyncHandler(enableBiometric))

// Tắt đăng nhập vân tay
router.post("/disable", authenticate, asyncHandler(disableBiometric))

// Đăng nhập bằng vân tay (public endpoint sau khi thiết bị quét vân tay thành công)
router.post("/login", validate(biometricLoginSchema), asyncHandler(biometricLogin))

module.exports = router
