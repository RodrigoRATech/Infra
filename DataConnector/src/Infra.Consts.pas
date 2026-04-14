unit Infra.Consts;

interface

const
   // ===== CONFIG ERRORS =====
   CFG_NOT_FOUND = 'O arquivo de configuração do sistema não foi encontrado.';

   // ===== HTTP STATUS CODES =====
   HTTP_OK = 200;
   HTTP_CREATED = 201;
   HTTP_NO_CONTENT = 204;
   HTTP_BAD_REQUEST = 400;
   HTTP_UNAUTHORIZED = 401;
   HTTP_FORBIDDEN = 403;
   HTTP_NOT_FOUND = 404;
   HTTP_NOT_ACCEPTABLE = 406;
   HTTP_CONFLICT = 409;
   HTTP_UNPROCESSABLE_ENTITY = 422;
   HTTP_TOO_MANY_REQUESTS = 429;
   HTTP_INTERNAL_SERVER_ERROR = 500;
   HTTP_SERVICE_UNAVAILABLE = 503;

implementation

end.
