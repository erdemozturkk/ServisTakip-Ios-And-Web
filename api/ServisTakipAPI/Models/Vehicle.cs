using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServisTakipAPI.Models
{
    [Table("vehicles")]
    public class Vehicle
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Column("driver_id")]
        public int? DriverId { get; set; }

        [Required]
        [MaxLength(20)]
        [Column("plate")]
        public string Plate { get; set; }

        [MaxLength(100)]
        [Column("model")]
        public string Model { get; set; }

        [Column("capacity")]
        public int? Capacity { get; set; }

        [Column("is_active")]
        public bool IsActive { get; set; }

        [ForeignKey("DriverId")]
        public User Driver { get; set; }
    }
}
