// {{PROJECT_NAME}} — ASP.NET Core Minimal API. 설정은 env 주입(.env.local | .env.prod).
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/health", (IConfiguration cfg) => Results.Ok(new
{
    status = "ok",
    env = cfg["APP_ENV"] ?? "local",
    db = new { engine = cfg["DB_ENGINE"] ?? "sqlite" }
}));

app.Run();

public partial class Program { }
