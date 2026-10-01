# {{PROJECT_NAME}} — csharp-dotnet (multi-stage: dev = local 모드, runtime = prod 모드)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS dev
WORKDIR /src
COPY src/Api/Api.csproj src/Api/
COPY test/Api.Tests/Api.Tests.csproj test/Api.Tests/
RUN dotnet restore src/Api/Api.csproj && dotnet restore test/Api.Tests/Api.Tests.csproj
COPY . .
ENV ASPNETCORE_URLS=http://0.0.0.0:8080 DOTNET_USE_POLLING_FILE_WATCHER=1
EXPOSE 8080
CMD ["dotnet", "watch", "run", "--project", "src/Api", "--no-launch-profile"]

FROM dev AS build
RUN dotnet publish src/Api/Api.csproj -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime
WORKDIR /app
# aspnet:8 이미지는 비루트 사용자 app 을 기본 제공
RUN mkdir -p /app/data && chown app /app/data
COPY --from=build /app/publish .
ENV ASPNETCORE_URLS=http://0.0.0.0:8080
USER app
EXPOSE 8080
ENTRYPOINT ["dotnet", "Api.dll"]
