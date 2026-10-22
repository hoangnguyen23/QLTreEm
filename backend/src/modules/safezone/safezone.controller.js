const safeZoneService = require("./safezone.service")

const createSafeZone = async (req, res) => {
  const result = await safeZoneService.createSafeZone({
    parentId: req.user.id,
    data: req.body,
  })
  res.status(201).json({
    message: "Tạo vùng an toàn thành công",
    data: result,
  })
}

const getSafeZones = async (req, res) => {
  const result = await safeZoneService.getSafeZones({
    user: req.user,
    query: req.query,
  })
  res.json({
    message: "Lấy danh sách vùng an toàn thành công",
    data: result,
  })
}

const getSafeZoneById = async (req, res) => {
  const result = await safeZoneService.getSafeZoneById({
    id: req.params.id,
    user: req.user,
  })
  res.json({
    message: "Lấy thông tin vùng an toàn thành công",
    data: result,
  })
}

const updateSafeZone = async (req, res) => {
  const result = await safeZoneService.updateSafeZone({
    id: req.params.id,
    user: req.user,
    data: req.body,
  })
  res.json({
    message: "Cập nhật vùng an toàn thành công",
    data: result,
  })
}

const deleteSafeZone = async (req, res) => {
  const result = await safeZoneService.deleteSafeZone({
    id: req.params.id,
    user: req.user,
  })
  res.json(result)
}

module.exports = {
  createSafeZone,
  getSafeZones,
  getSafeZoneById,
  updateSafeZone,
  deleteSafeZone,
}
