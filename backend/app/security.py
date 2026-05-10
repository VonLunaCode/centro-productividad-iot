import jwt
from datetime import datetime, timedelta, timezone
from typing import Optional
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from .config import settings
from .database import fetch_one

# Configuración de hashing con Argon2ID
ph = PasswordHasher()

# Esquema para extraer el token Bearer de la cabecera Authorization
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

def hash_password(password: str) -> str:
    """Hashea una contraseña usando Argon2."""
    return ph.hash(password)

def verify_password(hashed_password: str, plain_password: str) -> bool:
    """Verifica una contraseña contra su hash."""
    try:
        return ph.verify(hashed_password, plain_password)
    except VerifyMismatchError:
        return False

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """Crea un token JWT con una expiración definida."""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.JWT_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme)):
    """
    Dependencia para proteger rutas. 
    Verifica el JWT y retorna el usuario actual desde la DB.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Credenciales inválidas o token expirado",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="El token ha expirado",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except (jwt.PyJWTError, ValueError):
        raise credentials_exception
        
    # Buscamos el usuario en la base de datos para asegurar que sigue existiendo
    # Nota: el 'sub' en el token es el ID del usuario como string
    user = await fetch_one("SELECT id, username FROM users WHERE id = $1", int(user_id))
    if user is None:
        raise credentials_exception
        
    return dict(user)
