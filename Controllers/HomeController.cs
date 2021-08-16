using levineally08152021.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using Microsoft.Extensions.Configuration;
using System.Globalization;

namespace levineally08152021.Controllers
{
    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;

        public HomeController(ILogger<HomeController> logger)
        {
            _logger = logger;
        }

        public ActionResult Index()
        {
            var _baseLimit = new ConfigurationBuilder().AddJsonFile("appsettings.json").Build().GetSection("MyConfig")["BaseLimit"];
            var _assetCieling = new ConfigurationBuilder().AddJsonFile("appsettings.json").Build().GetSection("MyConfig")["AssetCieling"];
            var _limitMultiplier = new ConfigurationBuilder().AddJsonFile("appsettings.json").Build().GetSection("MyConfig")["LimitMultiplier"];

            DataSet ds = new DataSet();
            string constr = new ConfigurationBuilder().AddJsonFile("appsettings.json").Build().GetSection("ConnectionStrings")["default"];
            using (SqlConnection con = new SqlConnection(constr))
            {
                string query = "dbo.CalculateApprovedBankLimits";
                using (SqlCommand cmd = new SqlCommand(query))
                {
                    cmd.Parameters.Add(new SqlParameter("@BaseLimit", Convert.ToDecimal(_baseLimit, CultureInfo.InvariantCulture)));
                    cmd.Parameters.Add(new SqlParameter("@AssetCieling", Convert.ToDecimal(_assetCieling, CultureInfo.InvariantCulture)));
                    cmd.Parameters.Add(new SqlParameter("@LimitMultiplier", Convert.ToDecimal(_limitMultiplier, CultureInfo.InvariantCulture)));
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Connection = con;
                    using (SqlDataAdapter sda = new SqlDataAdapter(cmd))
                    {
                        sda.Fill(ds);
                    }
                }
            }
            return View(ds);
        }

        public IActionResult Privacy()
        {
            return View();
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}
