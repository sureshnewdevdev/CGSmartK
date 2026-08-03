using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;

namespace CGSmartK.Web.Security;

public sealed class DevelopmentAuthenticationHandler(
    IOptionsMonitor<AuthenticationSchemeOptions> options,
    ILoggerFactory logger,
    UrlEncoder encoder) : AuthenticationHandler<AuthenticationSchemeOptions>(options, logger, encoder)
{
    public const string SchemeName = "Development";

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        var admin = string.Equals(Request.Query["as"], "admin", StringComparison.OrdinalIgnoreCase);
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, admin ? "dev-admin" : "dev-employee"),
            new Claim(ClaimTypes.Name, admin ? "Development Administrator" : "Development Employee"),
            new Claim(ClaimTypes.Role, admin ? "KnowledgeAdministrator" : "Employee"),
            new Claim("groups", admin ? "knowledge-admins" : "employees")
        };
        var principal = new ClaimsPrincipal(new ClaimsIdentity(claims, SchemeName));

        return Task.FromResult(AuthenticateResult.Success(new AuthenticationTicket(principal, SchemeName)));
    }
}

public sealed class EasyAuthAuthenticationHandler(
    IOptionsMonitor<AuthenticationSchemeOptions> options,
    ILoggerFactory logger,
    UrlEncoder encoder) : AuthenticationHandler<AuthenticationSchemeOptions>(options, logger, encoder)
{
    public const string SchemeName = "EasyAuth";

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        var id = Request.Headers["X-MS-CLIENT-PRINCIPAL-ID"].FirstOrDefault();
        if (string.IsNullOrWhiteSpace(id))
        {
            return Task.FromResult(AuthenticateResult.NoResult());
        }

        var name = Request.Headers["X-MS-CLIENT-PRINCIPAL-NAME"].FirstOrDefault() ?? id;
        var roles = Request.Headers["X-MS-CLIENT-PRINCIPAL-ROLE"]
            .SelectMany(value => (value ?? string.Empty).Split(',', StringSplitOptions.RemoveEmptyEntries));
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, id),
            new(ClaimTypes.Name, name)
        };
        claims.AddRange(roles.Select(role => new Claim(ClaimTypes.Role, role.Trim())));
        var principal = new ClaimsPrincipal(new ClaimsIdentity(claims, SchemeName));

        return Task.FromResult(AuthenticateResult.Success(new AuthenticationTicket(principal, SchemeName)));
    }
}
