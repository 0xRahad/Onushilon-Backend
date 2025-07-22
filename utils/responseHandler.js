function successResponse(
  res,
  statusCode = 200,
  message = "Operation successful",
  data = null
) {
  const response = {
    success: true,
    message,
  };

  if (data && Object.keys(data).length > 0) {
    response.data = data;
  }

  return res.status(statusCode).json(response);
}

function errorResponse(
  res,
  statusCode = 500,
  message = "An error occurred",
  error = null
) {
  const response = {
    success: false,
    message,
  };

  if (error && Object.keys(error).length > 0) {
    response.error = error;
  }

  return res.status(statusCode).json(response);
}

function paginatedResponse(
  res,
  statusCode = 200,
  message = "Data fetched successfully",
  items = [],
  pagination = {}
) {
  const response = {
    success: true,
    message,
    data: items,
    pagination,
  };

  if (pagination && Object.keys(pagination).length > 0) {
    response.data.pagination = pagination;
  }

  return res.status(statusCode).json(response);
}

module.exports = {
  successResponse,
  errorResponse,
  paginatedResponse,
};
