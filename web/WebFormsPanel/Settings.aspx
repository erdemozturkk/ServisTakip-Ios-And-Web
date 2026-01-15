<%@ Page Title="Ayarlar" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Settings.aspx.cs" Inherits="WebFormsPanel.Settings" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="top-navbar">
        <h2><i class="bi bi-gear"></i> Ayarlar</h2>
    </div>

    <asp:Label ID="lblMessage" runat="server" CssClass="alert alert-info" Visible="false"></asp:Label>

    <div class="row g-4">
        <div class="col-md-6">
            <div class="card border-0 shadow-sm">
                <div class="card-header bg-white">
                    <h5 class="mb-0"><i class="bi bi-person-circle"></i> Profil Bilgileri</h5>
                </div>
                <div class="card-body">
                    <div class="mb-3">
                        <label class="form-label">Ad Soyad</label>
                        <asp:TextBox ID="txtUserName" runat="server" CssClass="form-control" ReadOnly="true"></asp:TextBox>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Email</label>
                        <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control" TextMode="Email" ReadOnly="true"></asp:TextBox>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Rol</label>
                        <asp:TextBox ID="txtRole" runat="server" CssClass="form-control" Text="Yönetici" ReadOnly="true"></asp:TextBox>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="col-md-6">
            <div class="card border-0 shadow-sm">
                <div class="card-header bg-white">
                    <h5 class="mb-0"><i class="bi bi-lock"></i> Şifre Değiştir</h5>
                </div>
                <div class="card-body">
                    <div class="mb-3">
                        <label class="form-label">Mevcut Şifre</label>
                        <asp:TextBox ID="txtCurrentPassword" runat="server" CssClass="form-control" TextMode="Password" required="required"></asp:TextBox>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Yeni Şifre</label>
                        <asp:TextBox ID="txtNewPassword" runat="server" CssClass="form-control" TextMode="Password" required="required"></asp:TextBox>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Yeni Şifre (Tekrar)</label>
                        <asp:TextBox ID="txtConfirmPassword" runat="server" CssClass="form-control" TextMode="Password" required="required"></asp:TextBox>
                    </div>
                    <asp:Button ID="btnChangePassword" runat="server" CssClass="btn btn-primary" Text="Şifreyi Değiştir" OnClick="btnChangePassword_Click" />
                </div>
            </div>
        </div>
    </div>
</asp:Content>
