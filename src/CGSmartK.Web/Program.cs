using CGSmartK.Infrastructure;
using CGSmartK.Web.Security;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Http.Features;
var builder=WebApplication.CreateBuilder(args);
builder.Services.AddControllersWithViews(o=>o.Filters.Add(new Microsoft.AspNetCore.Mvc.AutoValidateAntiforgeryTokenAttribute()));
builder.Services.AddApplicationInsightsTelemetry();
builder.Services.Configure<FormOptions>(o=>o.MultipartBodyLengthLimit=20*1024*1024);
var auth=builder.Environment.IsDevelopment()?DevelopmentAuthenticationHandler.SchemeName:EasyAuthAuthenticationHandler.SchemeName;
builder.Services.AddAuthentication(auth).AddScheme<AuthenticationSchemeOptions,DevelopmentAuthenticationHandler>(DevelopmentAuthenticationHandler.SchemeName,_=>{}).AddScheme<AuthenticationSchemeOptions,EasyAuthAuthenticationHandler>(EasyAuthAuthenticationHandler.SchemeName,_=>{});
builder.Services.AddAuthorization(o=>{o.AddPolicy("Employee",p=>p.RequireAuthenticatedUser().RequireRole("Employee","KnowledgeAdministrator"));o.AddPolicy("KnowledgeAdministrator",p=>p.RequireAuthenticatedUser().RequireRole("KnowledgeAdministrator"));});
builder.Services.AddSmartAssistInfrastructure(builder.Configuration,!builder.Environment.IsDevelopment());
builder.Services.AddHealthChecks();
var app=builder.Build();if(!app.Environment.IsDevelopment()){app.UseExceptionHandler("/Home/Error");app.UseHsts();}app.Use(async(ctx,next)=>{ctx.Response.Headers.Append("X-Content-Type-Options","nosniff");ctx.Response.Headers.Append("X-Frame-Options","DENY");ctx.Response.Headers.Append("Referrer-Policy","no-referrer");ctx.Response.Headers.Append("Content-Security-Policy","default-src 'self'; style-src 'self' https://cdn.jsdelivr.net; script-src 'self'; img-src 'self' data:");await next();});app.UseHttpsRedirection();app.UseStaticFiles();app.UseRouting();app.UseAuthentication();app.UseAuthorization();app.MapHealthChecks("/health/live",new(){Predicate=_=>false});app.MapHealthChecks("/health/ready");app.MapControllerRoute("default","{controller=Home}/{action=Index}/{id?}");app.Run();
public partial class Program { }
