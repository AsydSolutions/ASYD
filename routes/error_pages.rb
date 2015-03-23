class ASYD < Sinatra::Application
  # 404 Error!
  not_found do
    status 404
    erb :'error_page/oops'
  end

  error 401 do
    status 401
    erb :'error_page/error401'
  end

  error 403 do
    status 403
    erb :'error_page/error403'
  end

  error 500 do
    status 500
    erb :'error_page/error500'
  end
end
