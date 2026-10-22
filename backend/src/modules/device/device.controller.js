const deviceService = require("./device.service")

const getDevices = async (req, res) => {
  const result = await deviceService.getDevices({ user: req.user })
  res.json({
    message: "Lấy danh sách thiết bị thành công",
    data: result,
  })
}

const getDeviceById = async (req, res) => {
  const result = await deviceService.getDeviceById({
    id: req.params.id,
    user: req.user,
  })
  res.json({
    message: "Lấy thông tin thiết bị thành công",
    data: result,
  })
}

const updateDevice = async (req, res) => {
  const result = await deviceService.updateDevice({
    id: req.params.id,
    user: req.user,
    data: req.body,
  })
  res.json({
    message: "Cập nhật thiết bị thành công",
    data: result,
  })
}

const deleteDevice = async (req, res) => {
  const result = await deviceService.deleteDevice({
    id: req.params.id,
    user: req.user,
  })
  res.json(result)
}

module.exports = {
  getDevices,
  getDeviceById,
  updateDevice,
  deleteDevice,
}
