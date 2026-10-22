const express = require("express")
const router = express.Router()
const asyncHandler = require("../../utils/asyncHandler")
const authenticate = require("../../middlewares/auth.middleware")
const authorize = require("../../middlewares/permission.middleware")
const validate = require("../../middlewares/validation.middleware")
const {
  createChild,
  getChildren,
  getChildById,
  updateChild,
  deleteChild,
} = require("./child.controller")
const {
  createChildSchema,
  updateChildSchema,
  idSchema,
} = require("./child.validate")

router.post("/", authenticate, authorize("PARENT"), validate(createChildSchema), asyncHandler(createChild))
router.get("/", authenticate, authorize("PARENT", "ADMIN", "CHILD"), asyncHandler(getChildren))
router.get("/:id", authenticate, authorize("PARENT", "ADMIN", "CHILD"), validate(idSchema), asyncHandler(getChildById))
router.patch("/:id", authenticate, authorize("PARENT", "ADMIN"), validate(updateChildSchema), asyncHandler(updateChild))
router.delete("/:id", authenticate, authorize("PARENT", "ADMIN"), validate(idSchema), asyncHandler(deleteChild))

module.exports = router
