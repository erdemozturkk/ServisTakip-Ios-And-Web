using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServisTakipAPI.Models
{
    [Table("users")]
    public class User
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        [Column("name")]
        public string Name { get; set; }

        [Required]
        [MaxLength(100)]
        [Column("email")]
        public string Email { get; set; }

        [MaxLength(20)]
        [Column("phone_number")]
        public string PhoneNumber { get; set; }

        [Required]
        [Column("password_hash")]
        public string PasswordHash { get; set; }

        [Required]
        [Column("role")]
        public int Role { get; set; } // 0=yolcu, 1=şoför, 2=admin

        [Column("created_at")]
        public DateTime? CreatedAt { get; set; }
    }
}
