using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace CrashSite4IIS.Controllers
{
    public class AVController : Controller
    {
        // GET: Crash
        [System.Runtime.InteropServices.DllImport("kernel32.dll")]
        private static extern void RtlZeroMemory(IntPtr dest, IntPtr size);

        public ActionResult Index()
        {
            RtlZeroMemory(new IntPtr(-1), new IntPtr(-1));
            return View();
        }
    }
}