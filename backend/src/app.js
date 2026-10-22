require("dotenv").config()
const express = require("express")
const errorMiddleware = require("./middlewares/error.middleware")
const cors = require("cors")
const cookieParser = require("cookie-parser")
const authRoutes = require("./modules/auth/auth.routes")
const userRoutes = require("./modules/user/user.routes")
const childRoutes = require("./modules/child/child.routes")
const deviceRoutes = require("./modules/device/device.routes")
const pairingRoutes = require("./modules/pairing/pairing.routes")
const locationRoutes = require("./modules/location/location.routes")
const safeZoneRoutes = require("./modules/safezone/safezone.routes")
const alertRoutes = require("./modules/alert/alert.routes")
const biometricRoutes = require("./modules/biometric/biometric.routes")

const app = express()
app.use(
  cors({
    origin: ["http://localhost:5173", "http://localhost:3000"],
    credentials: true,
  }),
)
app.use(cookieParser())

app.use(express.json())

// Application Routes
app.use("/api/auth", authRoutes)
app.use("/api/users", userRoutes)
app.use("/api/children", childRoutes)
app.use("/api/devices", deviceRoutes)
app.use("/api/pairings", pairingRoutes)
app.use("/api/locations", locationRoutes)
app.use("/api/safezones", safeZoneRoutes)
app.use("/api/alerts", alertRoutes)
app.use("/api/biometric", biometricRoutes)

app.use(errorMiddleware)
module.exports = app
