// Everything a visitor reads lives in this file. Every value below is sample
// content: replace it with your own, then set [showSampleBanner] to false.

const showSampleBanner = false;

const nameLines = ['Jeva', 'Vignesh'];
const fullName = 'Jeva Vignesh';
const initials = 'JV';
const role = 'Systems developer / C++';
const location = 'Bengaluru, India';
const availability = 'Open to systems roles';
const tagline =
    'I build the software other software stands on: low-latency engines, '
    'allocators, schedulers and the tooling that keeps them honest.';

const aboutParagraphs = [
  'I care about what the machine actually does. That means reading the '
      'profile before the code, laying data out for the cache, and treating every '
      'lock as a decision that has to justify itself.',
  'My work sits between the language and the kernel, where a stray allocation '
      'shows up as tail latency and a wrong memory order shows up at 3am. I like '
      'making that layer boring, measurable and fast.',
];

const engineerCode = r'''
#pragma once
#include <concepts>
#include <string_view>

// Compiles clean with -Wall -Wextra -Werror.
struct Engineer {
  std::string_view name = "Jeva Vignesh";
  std::string_view base = "Bangalore";
  int years_in_cpp      = 3;

  static constexpr auto focus = {
    "low latency", "memory", "concurrency",
  };

  [[nodiscard]] auto solve(auto problem) const
      noexcept requires std::movable<decltype(problem)> {
    measure(problem);    // profile first
    auto fix = simplify(std::move(problem));
    return verify(fix);  // ASan, TSan, benchmarks
  }
};
''';

class Stat {
  const Stat(this.value, this.suffix, this.label);
  final int value;
  final String suffix;
  final String label;
}

const stats = [
  Stat(3, '+', 'years writing C++'),
  Stat(40, '%', 'typical p99 reduction'),
  Stat(12, '', 'production services shipped'),
];

class StackLayer {
  const StackLayer(this.name, this.note, this.skills);
  final String name;
  final String note;
  final List<String> skills;
}

/// Ordered from nearest the hardware to nearest the developer.
const stackLayers = [
  StackLayer('Silicon', 'cache lines, not abstractions', [
    'SIMD / AVX2',
    'Cache-aware layout',
    'Branch prediction',
    'NUMA',
    'perf counters',
  ]),
  StackLayer('Kernel', 'where the syscalls land', [
    'Linux internals',
    'io_uring',
    'epoll',
    'eBPF',
    'mmap',
    'Sockets',
  ]),
  StackLayer('Concurrency', 'correct first, then fast', [
    'Atomics',
    'Memory ordering',
    'Lock-free queues',
    'Work stealing',
    'Thread pools',
  ]),
  StackLayer('Language', 'modern C++, used on purpose', [
    'C++20 / 23',
    'Templates',
    'Concepts',
    'Coroutines',
    'RAII',
    'C',
    'Rust',
    'Python',
  ]),
  StackLayer('Toolchain', 'proof that it works', [
    'CMake',
    'Clang / GCC',
    'gdb / lldb',
    'ASan / TSan',
    'Valgrind',
    'Google Benchmark',
    'CI',
  ]),
];

enum ProjectVisual { simdCompression, gateway, ragPipeline }

class Project {
  const Project({
    required this.title,
    required this.kicker,
    required this.summary,
    required this.tags,
    required this.metrics,
    required this.visual,
  });
  final String title;
  final String kicker;
  final String summary;
  final List<String> tags;
  final List<(String, String)> metrics;
  final ProjectVisual visual;
}

const projects = [
  Project(
    title: 'Zstd 4-bit SIMD',
    kicker: 'Compression performance',
    summary:
        'Zstandard compression for 4-bit ML model weights, tuned at the '
        'instruction level. Hot encoding paths were vectorized with SIMD and '
        'bit-level packing was reworked, so more data moves through each '
        'cycle and overall compression performance improved.',
    tags: ['Zstd', 'AVX2 / AVX-512', 'C++', 'Bit packing'],
    metrics: [('4-bit', 'weight encoding'), ('AVX-512', 'widest SIMD target')],
    visual: ProjectVisual.simdCompression,
  ),
  Project(
    title: 'RDK-B Gateway',
    kicker: 'Broadband optimization',
    summary:
        'Optimization of the RDK-B software stack on a gateway that combines '
        'a cable modem and a router in one device. The work spans the path '
        'from the cable network to connected clients, so the gateway runs '
        'leaner and more reliably.',
    tags: ['RDK-B', 'Cable modem', 'Router', 'Embedded Linux'],
    metrics: [('RDK-B', 'software stack'), ('2-in-1', 'modem and router')],
    visual: ProjectVisual.gateway,
  ),
  Project(
    title: 'Log Analysis RAG',
    kicker: 'Debugging automation',
    summary:
        'An automation tool that turns long, noisy logs into answers. A RAG '
        'pipeline indexes the logs, retrieves the sections relevant to a '
        'failure, and passes them to an LLM, which cuts the manual searching '
        'in root cause analysis.',
    tags: ['RAG', 'LLM', 'Vector search', 'Log analysis', 'Automation'],
    metrics: [('RAG', 'retrieval pipeline'), ('Logs', 'to likely root cause')],
    visual: ProjectVisual.ragPipeline,
  ),
];

class JobSection {
  const JobSection({
    this.heading,
    this.client,
    this.summary,
    required this.points,
  });
  final String? heading;
  final String? client;
  final String? summary;
  final List<String> points;
}

class Job {
  const Job({
    required this.company,
    required this.title,
    required this.period,
    required this.sections,
  });
  final String company;
  final String title;
  final String period;
  final List<JobSection> sections;
}

/// Most recent first, which is also how a backtrace reads.
const jobs = [
  Job(
    company: 'ITC Infotech',
    title: 'Systems Engineer',
    period: '2025 - now',
    sections: [
      JobSection(
        heading: 'Current role: Camera Systems Engineer / Camera HAL Engineer',
        client: 'Samsung Semiconductor Research',
        summary:
            'Working on Qualcomm-based camera platforms, contributing to Camera '
            'HAL development, debugging, validation, and performance analysis '
            'across Android camera subsystems.',
        points: [
          'Investigating and resolving camera pipeline issues involving sensor '
              'initialization, stream configuration, capture requests, frame '
              'processing, and image quality validation.',
          'Performing root cause analysis of camera failures, performance '
              'bottlenecks, and stability issues using Android debugging tools, '
              'log analysis, and cross-functional collaboration with platform '
              'and vendor teams.',
          'Supporting camera feature integration, bring-up activities, and '
              'validation on new hardware platforms, ensuring compliance with '
              'functional and performance requirements.',
          'Developing internal automation and analysis tools to improve '
              'debugging efficiency, log processing, performance monitoring, '
              'and validation workflows.',
          'Collaborating with camera algorithm, platform, and chipset teams to '
              'analyze complex imaging issues and improve overall camera system '
              'reliability.',
        ],
      ),
      JobSection(
        heading: 'Previous contributions: Systems & Performance Engineering',
        points: [
          'Optimized GenAI model weight compression pipelines using SIMD '
              'vectorization (AVX2/AVX-512) and low-level C++ performance '
              'tuning, improving throughput and reducing latency across Linux '
              'and Windows environments.',
          'Worked on entropy coding and compression techniques including '
              'Zstandard (Zstd), Huffman encoding, and bit-level optimizations '
              'for efficient ML model weight storage and transmission.',
          'Developed synthetic test-vector generation and statistical analysis '
              'frameworks for compression evaluation using heavy-tailed '
              'distribution modeling and Gini coefficient analysis.',
          'Built automated validation and test frameworks for parallel '
              'encoding/decoding pipelines, improving correctness verification '
              'and cross-platform reliability.',
        ],
      ),
    ],
  ),
  Job(
    company: 'Tata Elxsi',
    title: 'Engineer',
    period: '2022 - 2024',
    sections: [
      JobSection(
        client: 'Vantiva ( Vodafone and VOO )',
        points: [
          "I've contributed to two impactful projects, Vodafone and VOO, "
              'showcasing proficiency in bug fixing across backend and frontend, '
              'as well as expertise in unit testing, smoke testing, and sanity '
              'testing.',
          'Utilizing tools like Jenkins for seamless integration, GitLab for '
              "continuous logic merging, and Jira for agile development and "
              "testing, I've played a pivotal role in project success.",
          'My collaboration skills extend to using Ubuntu server for effective '
              'team collaboration and providing optimal solutions.',
          'Complementing my experience, I completed a 6-month networking '
              'training program.',
          'I take pride in being part of the successful delivery of both '
              'projects to satisfied customers.',
        ],
      ),
    ],
  ),
];

class ContactLink {
  const ContactLink(this.label, this.value, this.url);
  final String label;
  final String value;
  final String url;
}

const contactLinks = [
  ContactLink(
    'email',
    'jevavignesh09@gmail.com',
    'mailto:jevavignesh09@gmail.com',
  ),
  ContactLink('github', 'github.com/jeva-dev', 'https://github.com/jeva-dev'),
  ContactLink(
    'linkedin',
    'linkedin.com/in/jeva-vignesh',
    'https://www.linkedin.com/in/jeva-vignesh/',
  ),
];
