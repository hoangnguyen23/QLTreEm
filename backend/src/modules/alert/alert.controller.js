const alertService = require("./alert.service")

const getAlerts = async (req, res) => {
  const result = await alertService.getAlerts({
    user: req.user,
    query: req.query,
  })
  res.json({
    message: "Lấy danh sách cảnh báo thành công",
    data: result,
  })
}

const triggerSos = async (req, res) => {
  const result = await alertService.triggerSos({
    user: req.user,
    data: req.body,
  })
  res.status(201).json({
    message: "Gửi tín hiệu SOS khẩn cấp thành công!",
    data: result,
  })
}

const markAlertRead = async (req, res) => {
  const result = await alertService.markAlertRead({
    id: req.params.id,
    user: req.user,
  })
  res.json({
    message: "Đánh dấu cảnh báo đã đọc thành công",
    data: result,
  })
}

const markAlertResolved = async (req, res) => {
  const result = await alertService.markAlertResolved({
    id: req.params.id,
    user: req.user,
  })
  res.json({
    message: "Xử lý cảnh báo thành công",
    data: result,
  })
}

const deleteAlert = async (req, res) => {
  const result = await alertService.deleteAlert({
    id: req.params.id,
    user: req.user,
  })
  res.json(result)
}

module.exports = {
  getAlerts,
  triggerSos,
  markAlertRead,
  markAlertResolved,
  deleteAlert,
}
