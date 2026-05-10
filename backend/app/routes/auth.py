from fastapi import APIRouter, HTTPException, status, Depends
from ..models import LoginRequest, RegisterRequest, TokenResponse, UserResponse
from ..services.auth_service import authenticate_user, register_user
from ..security import create_access_token, get_current_user

router = APIRouter(prefix="/auth", tags=["Auth"])

@router.post("/login", response_model=TokenResponse)
async def login(request: LoginRequest):
    """
    Endpoint para iniciar sesión. 
    Verifica credenciales y retorna un JWT si son válidas.
    """
    user = await authenticate_user(request.username, request.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario o contraseña incorrectos",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Creamos el token. El 'sub' (subject) es el ID del usuario.
    access_token = create_access_token(data={"sub": str(user["id"])})
    
    return {
        "access_token": access_token,
        "token_type": "bearer"
    }

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(request: RegisterRequest):
    """
    Registra un nuevo usuario. Retorna 409 si el username ya está en uso.
    """
    user = await register_user(request.username, request.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El nombre de usuario ya está en uso.",
        )
    return user

@router.get("/me", response_model=UserResponse)
async def get_me(current_user: dict = Depends(get_current_user)):
    """
    Retorna la información del usuario actual. 
    Sirve para validar que el token sigue siendo válido.
    """
    return current_user
