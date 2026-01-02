# Frontend

React 19 + TypeScript + Vite で構築されたフロントエンドアプリケーション。

## 技術スタック

- **React 19** - UIライブラリ
- **TypeScript** - 型安全なJavaScript
- **Vite** - 高速ビルドツール
- **AWS Amplify** - 認証 (Cognito連携)

### 開発ツール

- **Vitest** - テストフレームワーク
- **Testing Library** - コンポーネントテスト
- **ESLint** - リンター
- **Prettier** - コードフォーマッター

## ディレクトリ構成

```
frontend/
├── public/              # 静的ファイル
├── src/
│   ├── assets/          # 画像・アイコン等
│   ├── test/
│   │   └── setup.ts     # テストセットアップ
│   ├── App.tsx          # ルートコンポーネント
│   ├── App.test.tsx     # テスト
│   ├── App.css
│   ├── index.css
│   └── main.tsx         # エントリーポイント
├── index.html
├── package.json
├── tsconfig.json
├── vite.config.ts
├── eslint.config.js
└── .prettierrc
```

## セットアップ

### 前提条件

- Node.js 22+
- npm

### インストール

```bash
npm install
```

## 開発

### 開発サーバー起動

```bash
npm run dev

# または Makefile から
make dev-frontend
```

http://localhost:5173 でアクセス

### テスト実行

```bash
# ウォッチモード
npm test

# 単発実行
npm test -- --run

# カバレッジ付き
npm run test:coverage
```

### リント & フォーマット

```bash
# ESLint
npm run lint

# Prettier (フォーマット)
npm run format

# Prettier (チェックのみ)
npm run format:check
```

### ビルド

```bash
npm run build
```

`dist/` ディレクトリに出力されます。

### プレビュー

```bash
npm run preview
```

ビルド済みファイルをローカルでプレビュー。

## 環境変数

Viteでは `VITE_` プレフィックスが必要:

```bash
# .env.local
VITE_API_URL=https://api.example.com
VITE_COGNITO_USER_POOL_ID=ap-northeast-1_xxxxx
VITE_COGNITO_CLIENT_ID=xxxxxxxxxx
```

コード内でのアクセス:

```typescript
const apiUrl = import.meta.env.VITE_API_URL
```

| 変数名                     | 説明                    |
|---------------------------|------------------------|
| VITE_API_URL              | バックエンドAPI URL      |
| VITE_COGNITO_USER_POOL_ID | Cognito User Pool ID   |
| VITE_COGNITO_CLIENT_ID    | Cognito Client ID      |

## AWS Amplify 認証設定

```typescript
// src/config/amplify.ts
import { Amplify } from 'aws-amplify'

Amplify.configure({
  Auth: {
    Cognito: {
      userPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID,
      userPoolClientId: import.meta.env.VITE_COGNITO_CLIENT_ID,
    },
  },
})
```

### 認証フック例

```typescript
import { signIn, signOut, getCurrentUser } from 'aws-amplify/auth'

// サインイン
await signIn({ username: 'user@example.com', password: 'password' })

// サインアウト
await signOut()

// 現在のユーザー取得
const user = await getCurrentUser()
```

## コンポーネント作成ガイド

### 基本構成

```typescript
// src/components/Button/Button.tsx
interface ButtonProps {
  label: string
  onClick: () => void
  disabled?: boolean
}

export function Button({ label, onClick, disabled = false }: ButtonProps) {
  return (
    <button onClick={onClick} disabled={disabled}>
      {label}
    </button>
  )
}
```

### テスト

```typescript
// src/components/Button/Button.test.tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, vi } from 'vitest'
import { Button } from './Button'

describe('Button', () => {
  it('renders label', () => {
    render(<Button label="Click me" onClick={() => {}} />)
    expect(screen.getByText('Click me')).toBeInTheDocument()
  })

  it('calls onClick when clicked', async () => {
    const handleClick = vi.fn()
    render(<Button label="Click me" onClick={handleClick} />)

    await userEvent.click(screen.getByText('Click me'))
    expect(handleClick).toHaveBeenCalledTimes(1)
  })
})
```

## API リクエスト

```typescript
// src/api/client.ts
const API_URL = import.meta.env.VITE_API_URL

export async function fetchApi<T>(path: string, options?: RequestInit): Promise<T> {
  const response = await fetch(`${API_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
  })

  if (!response.ok) {
    throw new Error(`API Error: ${response.status}`)
  }

  return response.json()
}

// 使用例
const data = await fetchApi<{ status: string }>('/health')
```

## デプロイ

ビルド成果物は S3 + CloudFront でホスティング:

```bash
# ビルド
npm run build

# S3 にアップロード
aws s3 sync dist/ s3://your-bucket-name --delete

# CloudFront キャッシュ削除
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

CI/CDでは `main` ブランチへのマージで自動デプロイされます。
