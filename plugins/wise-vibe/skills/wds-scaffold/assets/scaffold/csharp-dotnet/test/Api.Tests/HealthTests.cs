using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

public class HealthTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    public HealthTests(WebApplicationFactory<Program> factory) => _factory = factory;

    [Fact]
    public async Task Health_returns_200()
    {
        var res = await _factory.CreateClient().GetAsync("/health");
        Assert.Equal(200, (int)res.StatusCode);
    }
}
