const nodemailer = require("nodemailer");

const transporter = nodemailer.createTransport({
  host: "smtp.gmail.com",
  port: 587,
  secure: false,
  auth: {
    user: "devrahsec@gmail.com",
    pass: "ghbpckkiipiezdgr",
  },
});

const sendResetOtp = async (email, otp) => {
  try {
    const mailOptions = {
      from: '"Onushilon" <devrahsec@gmail.com>',
      to: email,
      subject: "Password Reset OTP - Onushilon",
      text: `Your password reset OTP is: ${otp}. This OTP will expire in 10 minutes.`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #333;">Password Reset Request</h2>
          <p>Hello,</p>
          <p>You have requested to reset your password. Please use the following OTP to proceed:</p>
          <div style="background-color: #f4f4f4; padding: 20px; text-align: center; margin: 20px 0;">
            <h1 style="color: #007bff; font-size: 32px; margin: 0; letter-spacing: 5px;">${otp}</h1>
          </div>
          <p><strong>This OTP will expire in 10 minutes.</strong></p>
          <p>If you didn't request this password reset, please ignore this email.</p>
          <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
          <p style="color: #666; font-size: 12px;">This is an automated email from Onushilon. Please do not reply.</p>
        </div>
      `,
    };

    const result = await transporter.sendMail(mailOptions);
    console.log("Reset OTP email sent successfully:", result.messageId);
    return { success: true, messageId: result.messageId };
  } catch (error) {
    console.error("Error sending reset OTP email:", error);
    throw error;
  }
};

module.exports = { sendResetOtp };
