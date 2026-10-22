const biometricService = require("./biometric.service")

const getBiometricStatus = async (req, res) => {
  const result = await biometricService.getBiometricStatus(req.user.id)
  res.json({
    message: "Lấy trạng thái sinh trắc học thành công",
    data: result,
  })
}

const enableBiometric = async (req, res) => {
  const result = await biometricService.enableBiometric(req.user)
  res.json(result)
}

const disableBiometric = async (req, res) => {
  const result = await biometricService.disableBiometric(req.user.id)
  res.json(result)
}

const biometricLogin = async (req, res) => {
  const result = await biometricService.biometricLogin(req.body)
  res.json({
    message: "Đăng nhập sinh trắc học thành công",
    data: result,
  })
}

module.exports = {
  getBiometricStatus,
  enableBiometric,
  disableBiometric,
  biometricLogin,
}
