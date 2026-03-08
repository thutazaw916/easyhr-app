import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: process.env.NODE_ENV === 'production' 
          ? 'https://easyhr-api.onrender.com/api/v1/:path*'
          : 'http://localhost:3000/api/v1/:path*',
      },
    ];
  },
};

export default nextConfig;
