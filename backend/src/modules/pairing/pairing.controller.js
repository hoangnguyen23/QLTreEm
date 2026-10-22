const pairingService = require("./pairing.service")

const generatePairing = async (req, res) => {
  const result = await pairingService.generatePairing({
    parentId: req.user.id,
    childProfileId: req.body.childProfileId,
  })
  res.status(201).json({
    message: "Tạo mã ghép nối QR thành công",
    data: result,
  })
}

const getPairingStatus = async (req, res) => {
  const result = await pairingService.getPairingStatus({
    id: req.params.id,
    user: req.user,
  })
  res.json({
    message: "Lấy trạng thái ghép nối thành công",
    data: result,
  })
}

const confirmPairing = async (req, res) => {
  const result = await pairingService.confirmPairing(req.body)
  res.json({
    message: result.message,
    data: result,
  })
}

module.exports = {
  generatePairing,
  getPairingStatus,
  confirmPairing,
}
