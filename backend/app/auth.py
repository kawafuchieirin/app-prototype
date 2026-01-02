"""Cognito JWT認証モジュール"""

from typing import Annotated, Any

import httpx
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from pydantic import BaseModel

from app.config import settings

security = HTTPBearer(auto_error=False)


class CognitoUser(BaseModel):
    """認証済みユーザー情報"""

    sub: str
    email: str | None = None
    username: str | None = None


class CognitoJWTVerifier:
    """Cognito JWTトークン検証クラス"""

    def __init__(self) -> None:
        self._jwks: dict[str, Any] | None = None

    @property
    def issuer(self) -> str:
        """JWTのissuerを取得"""
        if settings.cognito_endpoint_url:
            # ローカル環境
            return settings.cognito_endpoint_url
        # AWS環境
        return f"https://cognito-idp.{settings.aws_region}.amazonaws.com/{settings.cognito_user_pool_id}"

    @property
    def jwks_url(self) -> str:
        """JWKSのURLを取得"""
        if settings.cognito_endpoint_url:
            # cognito-localはJWKSエンドポイントがないため、トークン検証をスキップ
            return ""
        return f"{self.issuer}/.well-known/jwks.json"

    async def get_jwks(self) -> dict[str, Any]:
        """JWKSを取得（キャッシュあり）"""
        if self._jwks is None:
            if not self.jwks_url:
                # ローカル環境ではJWKSなし
                return {"keys": []}
            async with httpx.AsyncClient() as client:
                response = await client.get(self.jwks_url)
                response.raise_for_status()
                self._jwks = response.json()
        return self._jwks

    async def verify_token(self, token: str) -> CognitoUser:
        """JWTトークンを検証してユーザー情報を返す"""
        try:
            # ローカル環境（cognito-local）の場合
            if settings.cognito_endpoint_url:
                # cognito-localのトークンは署名検証をスキップ
                unverified_claims = jwt.get_unverified_claims(token)
                return CognitoUser(
                    sub=unverified_claims.get("sub", ""),
                    email=unverified_claims.get("email"),
                    username=unverified_claims.get("cognito:username"),
                )

            # AWS環境の場合
            jwks = await self.get_jwks()

            # トークンのヘッダーからkidを取得
            unverified_header = jwt.get_unverified_header(token)
            kid = unverified_header.get("kid")

            # 対応する公開鍵を探す
            rsa_key = {}
            for key in jwks.get("keys", []):
                if key.get("kid") == kid:
                    rsa_key = {
                        "kty": key["kty"],
                        "kid": key["kid"],
                        "use": key["use"],
                        "n": key["n"],
                        "e": key["e"],
                    }
                    break

            if not rsa_key:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid token: key not found",
                )

            # トークンを検証
            payload = jwt.decode(
                token,
                rsa_key,
                algorithms=["RS256"],
                audience=settings.cognito_client_id,
                issuer=self.issuer,
            )

            return CognitoUser(
                sub=payload.get("sub", ""),
                email=payload.get("email"),
                username=payload.get("cognito:username"),
            )

        except JWTError as e:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Invalid token: {e!s}",
            ) from e


# シングルトンインスタンス
jwt_verifier = CognitoJWTVerifier()


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(security)],
) -> CognitoUser:
    """現在のユーザーを取得（認証必須）"""
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return await jwt_verifier.verify_token(credentials.credentials)


async def get_current_user_optional(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(security)],
) -> CognitoUser | None:
    """現在のユーザーを取得（認証オプション）"""
    if credentials is None:
        return None

    try:
        return await jwt_verifier.verify_token(credentials.credentials)
    except HTTPException:
        return None


# 依存性注入用の型エイリアス
CurrentUser = Annotated[CognitoUser, Depends(get_current_user)]
OptionalUser = Annotated[CognitoUser | None, Depends(get_current_user_optional)]
