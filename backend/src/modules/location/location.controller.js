const locationService = require("./location.service")

const reportLocation = async (req, res) => {
  const result = await locationService.reportLocation({
    user: req.user,
    data: req.body,
  })
  res.status(201).json({
    message: "Báo cáo vị trí GPS thành công",
    data: result,
  })
}

const getLatestLocation = async (req, res) => {
  const result = await locationService.getLatestLocation({
    deviceId: req.params.deviceId,
    user: req.user,
  })
  res.json({
    message: "Lấy vị trí mới nhất thành công",
    data: result,
  })
}

const getLocationHistory = async (req, res) => {
  const result = await locationService.getLocationHistory({
    deviceId: req.params.deviceId,
    user: req.user,
    query: req.query,
  })
  res.json({
    message: "Lấy lịch sử vị trí thành công",
    data: result,
  })
}

module.exports = {
  reportLocation,
  getLatestLocation,
  getLocationHistory,
}
