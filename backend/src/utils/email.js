
const nodemailer = require("nodemailer");

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || "smtp.gmail.com",
  port: Number(process.env.SMTP_PORT || 587),
  secure: Number(process.env.SMTP_PORT || 587) === 465,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

const sendOtpEmail = async (email, otp, purpose) => {
  const action =
    purpose === "REGISTER" ? "đăng ký tài khoản" : "đăng nhập";

  await transporter.sendMail({
    from: process.env.SMTP_FROM || process.env.SMTP_USER,
    to: email,
    subject: "Mã OTP xác minh tài khoản",
    text: `Mã OTP để ${action} là ${otp}. Mã hết hạn sau 5 phút.`,
    html: `
      <h2>Xác minh tài khoản</h2>
      <p>Mã OTP để ${action} của bạn:</p>
      <h1 style="letter-spacing: 6px">${otp}</h1>
      <p>Mã chỉ có hiệu lực trong 5 phút.</p>
      <p>Không chia sẻ mã này với bất kỳ ai.</p>
    `,
  });
};

module.exports = { sendOtpEmail };
