const isValidEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};
const isValidPhone = (phone) => {
  const phoneStr = phone.toString().replace(/\D/g, "");
  return phoneStr.length >= 10;
};

const isValidPassword = (password, minLength = 6) => {
  return password && password.length >= minLength;
};

const isValidRole = (role) => {
  const validRoles = ["user", "moderator", "admin"];
  return validRoles.includes(role);
};

module.exports = {
  isValidEmail,
  isValidPhone,
  isValidPassword,
  isValidRole,
};
