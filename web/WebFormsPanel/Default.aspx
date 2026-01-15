<%@ Page Title="Dashboard" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="WebFormsPanel._Default" Async="true" EnableEventValidation="false" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="card border-0 shadow-sm mb-4">
        <div class="card-body">
            <h2><i class="bi bi-speedometer2"></i> Dashboard</h2>
            <small class="text-muted">Son güncelleme: <%= DateTime.Now.ToString("dd.MM.yyyy HH:mm") %></small>
        </div>
    </div>

    <div class="row g-4 mb-4">
        <div class="col-md-3">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <div class="text-primary">
                            <i class="bi bi-bus-front-fill" style="font-size: 32px;"></i>
                        </div>
                        <div class="text-end">
                            <h3 class="mb-0"><asp:Label ID="lblActiveVehicles" runat="server" Text="0" /></h3>
                            <small class="text-muted">Aktif Araç</small>
                        </div>
                    </div>
                    <div class="progress" style="height: 5px;">
                        <div class="progress-bar bg-primary" role="progressbar" style="width: 75%"></div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="col-md-3">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <div class="text-warning">
                            <i class="bi bi-clock-history" style="font-size: 32px;"></i>
                        </div>
                        <div class="text-end">
                            <h3 class="mb-0"><asp:Label ID="lblLateVehicles" runat="server" Text="0" /></h3>
                            <small class="text-muted">Gecikmeli</small>
                        </div>
                    </div>
                    <div class="progress" style="height: 5px;">
                        <div class="progress-bar bg-warning" role="progressbar" style="width: 35%"></div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="col-md-3">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <div class="text-success">
                            <i class="bi bi-check-circle-fill" style="font-size: 32px;"></i>
                        </div>
                        <div class="text-end">
                            <h3 class="mb-0"><asp:Label ID="lblCompletedRoutes" runat="server" Text="0" /></h3>
                            <small class="text-muted">Tamamlanan</small>
                        </div>
                    </div>
                    <div class="progress" style="height: 5px;">
                        <div class="progress-bar bg-success" role="progressbar" style="width: 90%"></div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="col-md-3">
            <div class="card border-0 shadow-sm h-100">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-center mb-3">
                        <div class="text-info">
                            <i class="bi bi-people-fill" style="font-size: 32px;"></i>
                        </div>
                        <div class="text-end">
                            <h3 class="mb-0">%<asp:Label ID="lblOccupancyRate" runat="server" Text="0" /></h3>
                            <small class="text-muted">Doluluk</small>
                        </div>
                    </div>
                    <div class="progress" style="height: 5px;">
                        <div class="progress-bar bg-info" role="progressbar" style="width: 68%"></div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="row g-4">
        <div class="col-md-8">
            <div class="card border-0 shadow-sm">
                <div class="card-header bg-white border-bottom-0">
                    <h5 class="mb-0"><i class="bi bi-bar-chart-fill"></i> Bugünün Rotaları</h5>
                </div>
                <div class="card-body">
                    <asp:GridView ID="gvRoutes" runat="server" CssClass="table table-hover" 
                                  AutoGenerateColumns="false" GridLines="None">
                        <Columns>
                            <asp:BoundField DataField="Name" HeaderText="Rota" />
                            <asp:BoundField DataField="VehiclePlate" HeaderText="Araç" />
                            <asp:BoundField DataField="DriverName" HeaderText="Şoför" />
                            <asp:BoundField DataField="StartTime" HeaderText="Başlangıç" DataFormatString="{0:HH:mm}" />
                            <asp:TemplateField HeaderText="Durum">
                                <ItemTemplate>
                                    <%# GetStatusBadge(Eval("Status").ToString()) %>
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                        <EmptyDataTemplate>
                            <div class="text-center py-5 text-muted">
                                <i class="bi bi-inbox" style="font-size: 48px;"></i>
                                <p class="mt-3">Bugün için planlanmış rota bulunmamaktadır.</p>
                            </div>
                        </EmptyDataTemplate>
                    </asp:GridView>
                </div>
            </div>
        </div>
        
        <div class="col-md-4">
            <div class="card border-0 shadow-sm">
                <div class="card-header bg-white border-bottom-0">
                    <h5 class="mb-0"><i class="bi bi-exclamation-triangle-fill text-warning"></i> Uyarılar</h5>
                </div>
                <div class="card-body">
                    <asp:Repeater ID="rptAlerts" runat="server">
                        <ItemTemplate>
                            <div class="mb-3 pb-3 border-bottom">
                                <div class="d-flex">
                                    <div class="flex-shrink-0">
                                        <%# GetAlertIcon(Eval("Type").ToString()) %>
                                    </div>
                                    <div class="flex-grow-1 ms-3">
                                        <p class="mb-1 small"><strong><%# Eval("Title") %></strong></p>
                                        <p class="mb-0 small text-muted"><%# Eval("Message") %></p>
                                        <small class="text-muted"><%# ((DateTime)Eval("Time")).ToString("HH:mm") %></small>
                                    </div>
                                </div>
                            </div>
                        </ItemTemplate>
                        <FooterTemplate>
                            <% if (rptAlerts.Items.Count == 0) { %>
                                <div class="text-center py-4 text-muted">
                                    <i class="bi bi-check-circle" style="font-size: 48px;"></i>
                                    <p class="mt-3">Herhangi bir uyarı bulunmamaktadır.</p>
                                </div>
                            <% } %>
                        </FooterTemplate>
                    </asp:Repeater>
                </div>
            </div>
        </div>
    </div>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="scripts" runat="server">
    <style>
        .card {
            transition: transform 0.2s;
        }
        
        .card:hover {
            transform: translateY(-5px);
        }
    </style>
</asp:Content>
