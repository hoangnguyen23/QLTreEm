const childService = require("./child.service")

const createChild = async (req, res) => {
  const result = await childService.createChild({
    parentId: req.user.id,
    data: req.body,
  })
  res.status(201).json({
    message: "Tạo hồ sơ trẻ thành công",
    data: result,
  })
}

const getChildren = async (req, res) => {
  const result = await childService.getChildren({ user: req.user })
  res.json({
    message: "Lấy danh sách hồ sơ trẻ thành công",
    data: result,
  })
}

const getChildById = async (req, res) => {
  const result = await childService.getChildById({
    id: req.params.id,
    user: req.user,
  })
  res.json({
    message: "Lấy thông tin hồ sơ trẻ thành công",
    data: result,
  })
}

const updateChild = async (req, res) => {
  const result = await childService.updateChild({
    id: req.params.id,
    user: req.user,
    data: req.body,
  })
  res.json({
    message: "Cập nhật hồ sơ trẻ thành công",
    data: result,
  })
}

const deleteChild = async (req, res) => {
  const result = await childService.deleteChild({
    id: req.params.id,
    user: req.user,
  })
  res.json(result)
}

module.exports = {
  createChild,
  getChildren,
  getChildById,
  updateChild,
  deleteChild,
}
