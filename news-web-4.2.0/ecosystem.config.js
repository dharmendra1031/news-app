module.exports = {
  apps: [
    {
      name: "news-ts",
      script: ".next/standalone/server.js",
      cwd: "./",
      instances: 1,
      exec_mode: "fork",
      env: {
        NODE_ENV: "production",
        PORT: process.env.PORT || 8004,
        HOSTNAME: "0.0.0.0",
      },
      max_memory_restart: "512M",
      out_file: "./logs/out.log",
      error_file: "./logs/error.log",
      merge_logs: true,
      time: true,
    },
  ],
};
