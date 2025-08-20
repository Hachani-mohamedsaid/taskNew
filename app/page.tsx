"use client"

import { useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Progress } from "@/components/ui/progress"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import {
  Smartphone,
  Users,
  CheckSquare,
  Shield,
  Calendar,
  BarChart3,
  MessageSquare,
  Paperclip,
  Bell,
  Target,
  Clock,
  Code,
  Database,
  Layers,
  GitBranch,
  Trophy,
  BookOpen,
} from "lucide-react"

export default function ProjectPlanPage() {
  const [activeWeek, setActiveWeek] = useState(1)

  const objectives = [
    "Implémenter un système d'authentification sécurisé",
    "Gérer des projets, tâches et sous-tâches",
    "Assigner les tâches à des membres",
    "Suivre l'avancement (statuts, deadlines)",
    "Gérer les notifications, fichiers et messages",
    "Offrir une interface moderne, responsive et intuitive",
  ]

  const features = [
    {
      icon: Shield,
      title: "Authentification",
      description: "Inscription/Connexion avec Firebase Auth, gestion du profil utilisateur",
      color: "bg-blue-500",
    },
    {
      icon: CheckSquare,
      title: "Gestion des tâches",
      description: "CRUD complet, affectation, statuts multiples, priorités",
      color: "bg-green-500",
    },
    {
      icon: Users,
      title: "Gestion de projets",
      description: "Création, modification, suppression, ajout de membres",
      color: "bg-purple-500",
    },
    {
      icon: MessageSquare,
      title: "Commentaires internes",
      description: "Chat en temps réel via Firestore pour chaque tâche",
      color: "bg-orange-500",
    },
    {
      icon: Paperclip,
      title: "Fichiers joints",
      description: "Upload et gestion via Firebase Storage",
      color: "bg-red-500",
    },
    {
      icon: Bell,
      title: "Notifications push",
      description: "Alertes d'assignation et rappels de deadline",
      color: "bg-yellow-500",
    },
    {
      icon: Calendar,
      title: "Vue calendrier",
      description: "Planning hebdomadaire des tâches",
      color: "bg-indigo-500",
    },
    {
      icon: BarChart3,
      title: "Dashboard statistiques",
      description: "Métriques de productivité et répartition des tâches",
      color: "bg-pink-500",
    },
  ]

  const timeline = [
    {
      week: 1,
      title: "Analyse & Setup",
      tasks: ["Analyse du besoin", "Maquettes UI", "Structure du projet"],
      progress: 100,
    },
    { week: 2, title: "Authentification", tasks: ["Firebase Auth", "Profil utilisateur"], progress: 85 },
    { week: 3, title: "Base de données", tasks: ["Gestion de projets", "Base Firestore"], progress: 70 },
    { week: 4, title: "Tâches principales", tasks: ["Création tâches", "Affectation", "Statuts"], progress: 55 },
    { week: 5, title: "Communication", tasks: ["Commentaires", "Notifications push"], progress: 40 },
    {
      week: 6,
      title: "Fonctionnalités avancées",
      tasks: ["Fichiers joints", "Dashboard", "Sous-tâches"],
      progress: 25,
    },
    { week: 7, title: "Interface & Tests", tasks: ["Vue calendrier", "Filtres", "Tests"], progress: 10 },
    { week: 8, title: "Finalisation", tasks: ["Rapport", "Démo", "Présentation"], progress: 0 },
  ]

  const technologies = [
    { name: "Flutter 3.x", type: "Framework", icon: Smartphone },
    { name: "Firebase Auth", type: "Authentification", icon: Shield },
    { name: "Firestore", type: "Base de données", icon: Database },
    { name: "Firebase Storage", type: "Stockage", icon: Paperclip },
    { name: "Firebase Messaging", type: "Notifications", icon: Bell },
    { name: "Provider/Riverpod", type: "État", icon: GitBranch },
  ]

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center space-x-4">
            <div className="p-3 bg-blue-600 rounded-lg">
              <Smartphone className="h-8 w-8 text-white" />
            </div>
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Application Mobile Collaborative</h1>
              <p className="text-gray-600 mt-1">Gestion de tâches en équipe avec Flutter & Firebase</p>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <Tabs defaultValue="overview" className="space-y-6">
          <TabsList className="grid w-full grid-cols-6">
            <TabsTrigger value="overview">Vue d'ensemble</TabsTrigger>
            <TabsTrigger value="objectives">Objectifs</TabsTrigger>
            <TabsTrigger value="features">Fonctionnalités</TabsTrigger>
            <TabsTrigger value="architecture">Architecture</TabsTrigger>
            <TabsTrigger value="timeline">Planning</TabsTrigger>
            <TabsTrigger value="technologies">Technologies</TabsTrigger>
          </TabsList>

          {/* Vue d'ensemble */}
          <TabsContent value="overview" className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Durée du projet</CardTitle>
                  <Clock className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">8 semaines</div>
                  <p className="text-xs text-muted-foreground">Stage de développement</p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Fonctionnalités</CardTitle>
                  <Target className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">10+</div>
                  <p className="text-xs text-muted-foreground">Modules principaux</p>
                </CardContent>
              </Card>

              <Card>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">Technologies</CardTitle>
                  <Code className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">Flutter</div>
                  <p className="text-xs text-muted-foreground">+ Firebase Suite</p>
                </CardContent>
              </Card>
            </div>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <BookOpen className="h-5 w-5" />
                  <span>Contexte du projet</span>
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-gray-700">
                  Ce projet de stage vise à concevoir et développer une application mobile multiplateforme permettant à
                  une équipe de collaborer efficacement autour de la gestion de tâches, en intégrant les services de
                  Firebase.
                </p>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="flex items-center space-x-2">
                    <Users className="h-5 w-5 text-blue-500" />
                    <span className="text-sm">Collaboration d'équipe</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Smartphone className="h-5 w-5 text-green-500" />
                    <span className="text-sm">Application mobile</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Database className="h-5 w-5 text-purple-500" />
                    <span className="text-sm">Backend Firebase</span>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Objectifs */}
          <TabsContent value="objectives" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <Target className="h-5 w-5" />
                  <span>Objectif général</span>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-lg text-gray-700">
                  Concevoir et développer une application mobile multiplateforme permettant à une équipe de collaborer
                  efficacement autour de la gestion de tâches, en intégrant les services de Firebase.
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Objectifs spécifiques</CardTitle>
                <CardDescription>Les fonctionnalités clés à implémenter</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {objectives.map((objective, index) => (
                    <div key={index} className="flex items-start space-x-3">
                      <div className="flex-shrink-0 w-6 h-6 bg-blue-100 rounded-full flex items-center justify-center mt-0.5">
                        <span className="text-xs font-medium text-blue-600">{index + 1}</span>
                      </div>
                      <p className="text-gray-700">{objective}</p>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Types d'utilisateurs</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="p-4 border rounded-lg">
                    <div className="flex items-center space-x-2 mb-2">
                      <Shield className="h-5 w-5 text-red-500" />
                      <span className="font-medium">Administrateur</span>
                    </div>
                    <p className="text-sm text-gray-600">Crée les projets, gère les membres, assigne les tâches</p>
                  </div>
                  <div className="p-4 border rounded-lg">
                    <div className="flex items-center space-x-2 mb-2">
                      <Users className="h-5 w-5 text-blue-500" />
                      <span className="font-medium">Membre</span>
                    </div>
                    <p className="text-sm text-gray-600">Visualise et modifie ses propres tâches</p>
                  </div>
                  <div className="p-4 border rounded-lg">
                    <div className="flex items-center space-x-2 mb-2">
                      <Users className="h-5 w-5 text-gray-500" />
                      <span className="font-medium">Invité (Optionnel)</span>
                    </div>
                    <p className="text-sm text-gray-600">Accès limité en lecture seule</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Fonctionnalités */}
          <TabsContent value="features" className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {features.map((feature, index) => (
                <Card key={index} className="hover:shadow-lg transition-shadow">
                  <CardHeader>
                    <div className="flex items-center space-x-3">
                      <div className={`p-2 rounded-lg ${feature.color}`}>
                        <feature.icon className="h-5 w-5 text-white" />
                      </div>
                      <CardTitle className="text-lg">{feature.title}</CardTitle>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <p className="text-gray-600">{feature.description}</p>
                  </CardContent>
                </Card>
              ))}
            </div>

            <Card>
              <CardHeader>
                <CardTitle>Fonctionnalités détaillées</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  <div>
                    <h4 className="font-medium mb-2">Gestion des tâches avancée</h4>
                    <div className="flex flex-wrap gap-2">
                      <Badge variant="secondary">À faire</Badge>
                      <Badge variant="secondary">En cours</Badge>
                      <Badge variant="secondary">Terminé</Badge>
                      <Badge variant="secondary">Archivé</Badge>
                    </div>
                  </div>
                  <div>
                    <h4 className="font-medium mb-2">Sous-tâches (checklists)</h4>
                    <p className="text-sm text-gray-600">
                      Chaque tâche peut contenir plusieurs étapes à cocher pour un suivi détaillé
                    </p>
                  </div>
                  <div>
                    <h4 className="font-medium mb-2">Permissions par rôle</h4>
                    <p className="text-sm text-gray-600">
                      Accès limité selon le type d'utilisateur pour une sécurité optimale
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Architecture */}
          <TabsContent value="architecture" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <Layers className="h-5 w-5" />
                  <span>Clean Architecture</span>
                </CardTitle>
                <CardDescription>Structure modulaire et maintenable</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="bg-gray-50 p-4 rounded-lg font-mono text-sm">
                  <div className="space-y-1">
                    <div>lib/</div>
                    <div className="ml-4">
                      ├── core/ <span className="text-gray-500"># Utils & constantes globales</span>
                    </div>
                    <div className="ml-4">├── features/</div>
                    <div className="ml-8">
                      │ └── tasks/ <span className="text-gray-500"># Feature principale</span>
                    </div>
                    <div className="ml-12">│ ├── data/</div>
                    <div className="ml-12">│ ├── domain/</div>
                    <div className="ml-12">│ └── presentation/</div>
                    <div className="ml-4">├── main.dart</div>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Services Firebase</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="flex items-center space-x-3 p-3 border rounded-lg">
                    <Shield className="h-5 w-5 text-blue-500" />
                    <div>
                      <div className="font-medium">Firebase Auth</div>
                      <div className="text-sm text-gray-600">Authentification</div>
                    </div>
                  </div>
                  <div className="flex items-center space-x-3 p-3 border rounded-lg">
                    <Database className="h-5 w-5 text-green-500" />
                    <div>
                      <div className="font-medium">Firestore</div>
                      <div className="text-sm text-gray-600">Base de données NoSQL</div>
                    </div>
                  </div>
                  <div className="flex items-center space-x-3 p-3 border rounded-lg">
                    <Bell className="h-5 w-5 text-orange-500" />
                    <div>
                      <div className="font-medium">Cloud Messaging</div>
                      <div className="text-sm text-gray-600">Notifications</div>
                    </div>
                  </div>
                  <div className="flex items-center space-x-3 p-3 border rounded-lg">
                    <Paperclip className="h-5 w-5 text-purple-500" />
                    <div>
                      <div className="font-medium">Firebase Storage</div>
                      <div className="text-sm text-gray-600">Fichiers</div>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Planning */}
          <TabsContent value="timeline" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Planning de réalisation - 8 semaines</CardTitle>
                <CardDescription>Répartition des tâches par semaine</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {timeline.map((week) => (
                    <div key={week.week} className="border rounded-lg p-4">
                      <div className="flex items-center justify-between mb-3">
                        <div className="flex items-center space-x-3">
                          <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                            <span className="text-sm font-medium text-blue-600">{week.week}</span>
                          </div>
                          <div>
                            <h4 className="font-medium">{week.title}</h4>
                            <p className="text-sm text-gray-600">Semaine {week.week}</p>
                          </div>
                        </div>
                        <Badge variant={week.progress > 50 ? "default" : "secondary"}>{week.progress}%</Badge>
                      </div>
                      <Progress value={week.progress} className="mb-3" />
                      <div className="flex flex-wrap gap-2">
                        {week.tasks.map((task, index) => (
                          <Badge key={index} variant="outline" className="text-xs">
                            {task}
                          </Badge>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Technologies */}
          <TabsContent value="technologies" className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {technologies.map((tech, index) => (
                <Card key={index}>
                  <CardHeader>
                    <div className="flex items-center space-x-3">
                      <tech.icon className="h-6 w-6 text-blue-500" />
                      <div>
                        <CardTitle className="text-lg">{tech.name}</CardTitle>
                        <CardDescription>{tech.type}</CardDescription>
                      </div>
                    </div>
                  </CardHeader>
                </Card>
              ))}
            </div>

            <Card>
              <CardHeader>
                <CardTitle>Packages Flutter supplémentaires</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <h4 className="font-medium">Gestion d'état</h4>
                    <div className="space-y-1 text-sm">
                      <div>• Provider ou Riverpod</div>
                    </div>
                  </div>
                  <div className="space-y-2">
                    <h4 className="font-medium">Firebase</h4>
                    <div className="space-y-1 text-sm">
                      <div>• cloud_firestore</div>
                      <div>• firebase_auth</div>
                      <div>• firebase_messaging</div>
                      <div>• firebase_storage</div>
                    </div>
                  </div>
                  <div className="space-y-2">
                    <h4 className="font-medium">Interface utilisateur</h4>
                    <div className="space-y-1 text-sm">
                      <div>• fl_chart (statistiques)</div>
                      <div>• table_calendar (calendrier)</div>
                    </div>
                  </div>
                  <div className="space-y-2">
                    <h4 className="font-medium">Sécurité</h4>
                    <div className="space-y-1 text-sm">
                      <div>• Firebase Security Rules</div>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <Trophy className="h-5 w-5" />
                  <span>Résultat attendu</span>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  <div className="flex items-center space-x-2">
                    <CheckSquare className="h-4 w-4 text-green-500" />
                    <span>Application mobile fonctionnelle (Android au minimum)</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <CheckSquare className="h-4 w-4 text-green-500" />
                    <span>Code commenté, structuré (Clean Architecture)</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <CheckSquare className="h-4 w-4 text-green-500" />
                    <span>Base Firebase bien organisée</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <CheckSquare className="h-4 w-4 text-green-500" />
                    <span>Sécurité des données (Firebase rules)</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <CheckSquare className="h-4 w-4 text-green-500" />
                    <span>Rapport technique + soutenance</span>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  )
}
