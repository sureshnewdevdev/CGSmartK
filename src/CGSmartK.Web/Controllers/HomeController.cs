using Microsoft.AspNetCore.Mvc; namespace CGSmartK.Web.Controllers; public sealed class HomeController:Controller { public IActionResult Index()=>View(); public IActionResult Error()=>View(); }
