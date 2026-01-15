using Microsoft.EntityFrameworkCore;
using ServisTakipAPI.Models;

namespace ServisTakipAPI.Data
{
    public class ServisTakipDbContext : DbContext
    {
        public ServisTakipDbContext(DbContextOptions<ServisTakipDbContext> options)
            : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Vehicle> Vehicles { get; set; }
        public DbSet<Stop> Stops { get; set; }
        public DbSet<DailyRoute> DailyRoutes { get; set; }
        public DbSet<RouteStop> RouteStops { get; set; }
        public DbSet<Reservation> Reservations { get; set; }
        public DbSet<VehicleLocation> VehicleLocations { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Tablo isimlerini küçük harfe çevir
            modelBuilder.Entity<User>().ToTable("users");
            modelBuilder.Entity<Vehicle>().ToTable("vehicles");
            modelBuilder.Entity<Stop>().ToTable("stops");
            modelBuilder.Entity<DailyRoute>().ToTable("daily_routes");
            modelBuilder.Entity<RouteStop>().ToTable("route_stops");
            modelBuilder.Entity<Reservation>().ToTable("reservations");
            modelBuilder.Entity<VehicleLocation>().ToTable("vehicle_locations");
        }
    }
}
