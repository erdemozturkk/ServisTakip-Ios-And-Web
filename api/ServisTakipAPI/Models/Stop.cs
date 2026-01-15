using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServisTakipAPI.Models
{
    [Table("stops")]
    public class Stop
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Column("user_id")]
        public int? UserId { get; set; }

        [MaxLength(100)]
        [Column("name")]
        public string Name { get; set; }

        [Required]
        [Column("latitude", TypeName = "decimal(9,6)")]
        public decimal Latitude { get; set; }

        [Required]
        [Column("longitude", TypeName = "decimal(9,6)")]
        public decimal Longitude { get; set; }

        [Column("is_active")]
        public bool IsActive { get; set; }

        [ForeignKey("UserId")]
        public User User { get; set; }
    }
}
